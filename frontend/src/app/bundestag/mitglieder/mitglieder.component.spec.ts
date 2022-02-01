import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MitgliederComponent } from './mitglieder.component';

describe('MitgliederComponent', () => {
  let component: MitgliederComponent;
  let fixture: ComponentFixture<MitgliederComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ MitgliederComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(MitgliederComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
