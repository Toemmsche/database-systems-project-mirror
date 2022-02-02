import { ComponentFixture, TestBed } from '@angular/core/testing';

import { StrukturdatenComponent } from './strukturdaten.component';

describe('StrukturdatenComponent', () => {
  let component: StrukturdatenComponent;
  let fixture: ComponentFixture<StrukturdatenComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ StrukturdatenComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(StrukturdatenComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
