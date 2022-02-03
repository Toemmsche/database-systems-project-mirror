import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BegrenzungComponent } from './begrenzung.component';

describe('BegrenzungComponent', () => {
  let component: BegrenzungComponent;
  let fixture: ComponentFixture<BegrenzungComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ BegrenzungComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(BegrenzungComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
